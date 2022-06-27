import {
  Realm,
  executableExtensions,
  baseOrigin,
  protocolRelativeBaseOrigin,
} from ".";
import { ModuleSyntax } from "./module-syntax";
import { ClassReference, PossibleCardClass } from "./schema-analysis-plugin";

export type CardRef =
  | {
      type: "exportedCard";
      module: string;
      name: string;
    }
  | {
      type: "ancestorOf";
      card: CardRef;
    }
  | {
      type: "fieldOf";
      card: CardRef;
      field: string;
    };

export function isCardRef(ref: any): ref is CardRef {
  if (typeof ref !== "object") {
    return false;
  }
  if (!("type" in ref)) {
    return false;
  }
  if (ref.type === "exportedCard") {
    if (!("module" in ref) || !("name" in ref)) {
      return false;
    }
    return typeof ref.module === "string" && typeof ref.name === "string";
  } else if (ref.type === "ancestorOf") {
    if (!("card" in ref)) {
      return false;
    }
    return isCardRef(ref.card);
  } else if (ref.type === "fieldOf") {
    if (!("card" in ref) || !("field" in ref)) {
      return false;
    }
    if (typeof ref.card !== "object" || typeof ref.field !== "string") {
      return false;
    }
    return isCardRef(ref.card);
  }
  return false;
}

// TODO
export type Saved = string;
export type Unsaved = string | undefined;
export interface CardResource<Identity extends Unsaved = Saved> {
  id: Identity;
  type: "card";
  attributes?: Record<string, any>;
  // TODO add relationships
  meta: {
    adoptsFrom: {
      module: string;
      name: string;
    };
  };
}
export interface CardDocument<Identity extends Unsaved = Saved> {
  data: CardResource<Identity>;
}

export function isCardResource(resource: any): resource is CardResource {
  if (typeof resource !== "object") {
    return false;
  }
  if ("id" in resource && typeof resource.id !== "string") {
    return false;
  }
  if (!("type" in resource) || resource.type !== "card") {
    return false;
  }
  if ("attributes" in resource && typeof resource.attributes !== "object") {
    return false;
  }
  if (!("meta" in resource) || typeof resource.meta !== "object") {
    return false;
  }
  let { meta } = resource;
  if (!("adoptsFrom" in meta) && typeof meta.adoptsFrom !== "object") {
    return false;
  }
  let { adoptsFrom } = meta;
  return (
    "module" in adoptsFrom &&
    typeof adoptsFrom.module === "string" &&
    "name" in adoptsFrom &&
    typeof adoptsFrom.name === "string"
  );
}
export function isCardDocument(doc: any): doc is CardDocument {
  if (typeof doc !== "object") {
    return false;
  }
  return "data" in doc && isCardResource(doc.data);
}

type Query = unknown;

interface CardDefinition {
  id: CardRef;
  key: string; // this is used to help for JSON-API serialization
  super: CardRef | undefined; // base card has no super
  fields: Map<
    string,
    {
      fieldType: "contains" | "containsMany";
      fieldCard: CardRef;
    }
  >;
}

function hasExecutableExtension(path: string): boolean {
  for (let extension of executableExtensions) {
    if (path.endsWith(extension)) {
      return true;
    }
  }
  return false;
}

function trimExecutableExtension(path: string): string {
  for (let extension of executableExtensions) {
    if (path.endsWith(extension)) {
      return path.replace(new RegExp(`\\${extension}$`), "");
    }
  }
  return path;
}

export class SearchIndex {
  private instances = new Map<string, CardResource>();
  private modules = new Map<string, ModuleSyntax>();
  private definitions = new Map<string, CardDefinition>();
  private exportedCardRefs = new Map<string, CardRef[]>();

  constructor(private realm: Realm) {}

  async run() {
    for await (let { path, contents } of this.realm.eachFile()) {
      path = new URL(path, this.realm.url).href;
      this.syntacticPhase(path, contents);
    }
    await this.semanticPhase();
  }

  async update(path: string, contents: string): Promise<void> {
    this.syntacticPhase(path, contents);
    await this.semanticPhase();
  }

  private syntacticPhase(path: string, contents: string) {
    if (path.endsWith(".json")) {
      let json = JSON.parse(contents);
      if (isCardDocument(json)) {
        json.data.id = path;
        this.instances.set(path, json.data);
      }
    } else if (hasExecutableExtension(path)) {
      let mod = new ModuleSyntax(contents);
      this.modules.set(path, mod);
      this.modules.set(trimExecutableExtension(path), mod);
    }
  }

  private async semanticPhase(): Promise<void> {
    let newDefinitions: Map<string, CardDefinition> = new Map();
    for (let [path, mod] of this.modules) {
      for (let possibleCard of mod.possibleCards) {
        if (possibleCard.exportedAs) {
          await this.buildDefinition(
            newDefinitions,
            path,
            mod,
            {
              type: "exportedCard",
              module: path,
              name: possibleCard.exportedAs,
            },
            possibleCard
          );
        }
      }
    }
    let newExportedCardRefs = new Map<string, CardRef[]>();
    for (let def of newDefinitions.values()) {
      if (def.id.type !== "exportedCard") {
        continue;
      }
      let { module } = def.id;
      let refs = newExportedCardRefs.get(module);
      if (!refs) {
        refs = [];
        newExportedCardRefs.set(module, refs);
      }
      refs.push(def.id);
    }

    // atomically update the search index
    this.definitions = newDefinitions;
    this.exportedCardRefs = newExportedCardRefs;
  }

  private async buildDefinition(
    definitions: Map<string, CardDefinition>,
    path: string,
    mod: ModuleSyntax,
    ref: CardRef,
    possibleCard: PossibleCardClass
  ): Promise<CardDefinition | undefined> {
    let id: CardRef = possibleCard.exportedAs
      ? {
          type: "exportedCard",
          module: new URL(path, this.realm.url).href,
          name: possibleCard.exportedAs,
        }
      : ref;

    let def = definitions.get(this.internalKeyFor(id));
    if (def) {
      definitions.set(this.internalKeyFor(ref), def);
      return def;
    }

    let superDef = await this.definitionForClassRef(
      definitions,
      path,
      mod,
      possibleCard.super,
      { type: "ancestorOf", card: id }
    );

    if (!superDef) {
      return undefined;
    }

    let fields: CardDefinition["fields"] = new Map(superDef.fields);

    for (let [fieldName, possibleField] of possibleCard.possibleFields) {
      if (!isOurFieldDecorator(possibleField.decorator, path)) {
        continue;
      }
      let fieldType = getFieldType(possibleField.type, path);
      if (!fieldType) {
        continue;
      }
      let fieldDef = await this.definitionForClassRef(
        definitions,
        path,
        mod,
        possibleField.card,
        { type: "fieldOf", card: id, field: fieldName }
      );
      if (fieldDef) {
        fields.set(fieldName, { fieldType, fieldCard: fieldDef.id });
      }
    }

    let key = this.internalKeyFor(id);
    def = { id, key, super: superDef.id, fields };
    definitions.set(key, def);
    return def;
  }

  private async definitionForClassRef(
    definitions: Map<string, CardDefinition>,
    path: string,
    mod: ModuleSyntax,
    ref: ClassReference,
    targetRef: CardRef
  ): Promise<CardDefinition | undefined> {
    if (ref.type === "internal") {
      return await this.buildDefinition(
        definitions,
        path,
        mod,
        targetRef,
        mod.possibleCards[ref.classIndex]
      );
    } else {
      if (this.isLocal(ref.module)) {
        let inner = this.lookupPossibleCard(ref.module, ref.name);
        if (!inner) {
          return undefined;
        }
        return await this.buildDefinition(
          definitions,
          ref.module,
          inner.mod,
          targetRef,
          inner.possibleCard
        );
      } else {
        return await this.getExternalCardDefinition(ref.module, ref.name);
      }
    }
  }

  private internalKeyFor(ref: CardRef): string {
    switch (ref.type) {
      case "exportedCard":
        let module = new URL(ref.module, this.realm.url).href;
        return `${module}/${ref.name}`;
      case "ancestorOf":
        return `${this.internalKeyFor(ref.card)}/ancestor`;
      case "fieldOf":
        return `${this.internalKeyFor(ref.card)}/fields/${ref.field}`;
    }
  }

  private lookupPossibleCard(
    module: string,
    exportedName: string
  ): { mod: ModuleSyntax; possibleCard: PossibleCardClass } | undefined {
    module = new URL(module, this.realm.url).href;
    let mod = this.modules.get(module);
    if (!mod) {
      // TODO: broken import seems bad
      return undefined;
    }
    let possibleCard = mod.possibleCards.find(
      (c) => c.exportedAs === exportedName
    );
    if (!possibleCard) {
      return undefined;
    }
    return { mod, possibleCard };
  }

  private getExternalCardDefinition(
    url: string,
    exportName: string
  ): Promise<CardDefinition | undefined> {
    // TODO This is scaffolding for the base realm, implement for real once we
    // have this realm endpoint fleshed out
    let module = url.startsWith("http:") ? url : `http:${url}`;
    let moduleURL = new URL(module);
    if (moduleURL.origin !== baseOrigin) {
      return Promise.resolve(undefined);
    }
    let path = moduleURL.pathname;
    switch (path) {
      case "/base/card-api":
        return exportName === "Card"
          ? Promise.resolve({
              id: {
                type: "exportedCard",
                module: url,
                name: exportName,
              },
              key: `${baseOrigin}${path}/Card`,
              super: undefined,
              fields: new Map(),
            })
          : Promise.resolve(undefined);
      case "/base/string":
      case "/base/integer":
      case "/base/date":
      case "/base/datetime":
        return exportName === "default"
          ? Promise.resolve({
              id: {
                type: "exportedCard",
                module: url,
                name: exportName,
              },
              super: {
                type: "exportedCard",
                module: `${baseOrigin}/base/card-api`,
                name: "Card",
              },
              key: `${baseOrigin}${path}/default`,
              fields: new Map(),
            })
          : Promise.resolve(undefined);
      case "/base/text-area":
        return exportName === "default"
          ? Promise.resolve({
              id: {
                type: "exportedCard",
                module: url,
                name: exportName,
              },
              super: {
                type: "exportedCard",
                module: `${baseOrigin}/base/string`,
                name: "default",
              },
              key: `${baseOrigin}${path}/default`,
              fields: new Map(),
            })
          : Promise.resolve(undefined);
    }
    throw new Error(
      `unimplemented: don't know how to look up card types for ${url}`
    );
  }

  private isLocal(url: string): boolean {
    return new URL(url, this.realm.url).href.startsWith(this.realm.url);
  }

  // TODO: complete these types
  async search(_query: Query): Promise<CardResource[]> {
    return [...this.instances.values()];
  }

  async typeOf(ref: CardRef): Promise<CardDefinition | undefined> {
    return this.definitions.get(this.internalKeyFor(ref));
  }

  async exportedCardsOf(module: string): Promise<CardRef[]> {
    module = new URL(module, this.realm.url).href;
    return this.exportedCardRefs.get(module) ?? [];
  }
}

function isOurFieldDecorator(ref: ClassReference, inModule: string): boolean {
  return (
    ref.type === "external" &&
    new URL(ref.module, inModule).href ===
      new URL(`${protocolRelativeBaseOrigin}/base/card-api`, inModule).href &&
    ref.name === "field"
  );
}

function getFieldType(
  ref: ClassReference,
  inModule: string
): "contains" | "containsMany" | undefined {
  if (
    ref.type === "external" &&
    new URL(ref.module, inModule).href ===
      new URL(`${protocolRelativeBaseOrigin}/base/card-api`, inModule).href &&
    ["contains", "containsMany"].includes(ref.name)
  ) {
    return ref.name as ReturnType<typeof getFieldType>;
  }
  return undefined;
}
