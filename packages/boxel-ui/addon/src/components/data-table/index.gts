import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn, concat, hash } from '@ember/helper';
import { get, set } from '@ember/object';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { next } from '@ember/runloop';
import { and, eq } from '@cardstack/boxel-ui/helpers';

export interface DataTableHeader {
  name: string
  value: string
  width?: string
};
export interface DataTableCell {
  [key: string]: string
};
interface Signature {
  Args: {
    tableHeaders: DataTableHeader[],
    tableCells: DataTableCell[],
    onDataChange: (updatedHeaders: DataTableHeader[], updatedCells: DataTableCell[]) => void;
  };
  Element: HTMLElement
}
type headerDataType = {
  id: string
  value: string
  headerIndex: number
}
type cellDataType = {
  id: string
  value: string
  parent: string
  cellIndex: number
  headerIndex: number
}

type editMode = {
  headerInput : boolean,
  cellInput: Boolean
}

export default class DataTable extends Component<Signature> {
  // track the props so i can make it mutable
  @tracked dataTableHeaders = [...this.args.tableHeaders];
  @tracked dataTableCells = [...this.args.tableCells];
  @tracked editedCell: { cellIndex: number; headerIndex: number } | null = null;
  @tracked editedHeader: number | null = null;
  @tracked editedValue: string = '';
  @tracked editInputMode: editMode = {
    headerInput:false,
    cellInput: false
  };
  @tracked errorMessage: string | null = null;
  validateData(): boolean {
    if (!Array.isArray(this.dataTableHeaders)) {
      this.errorMessage = 'Data Headers should be an array.';
      return false;
    }
    if (!Array.isArray(this.dataTableCells)) {
      this.errorMessage = 'Data Cells should be an array.';
      return false;
    }

    const expectedKeys = this.dataTableHeaders.map(header => header.value);
    for (const cell of this.dataTableCells) {
      const cellKeys = Object.keys(cell);
      if (!expectedKeys.every(key => cellKeys.includes(key))) {
        this.errorMessage = `Table Data is missing some expected Table Cell. Expected Table Cell: ${expectedKeys.join(', ')}.`;
        return false;
      }

      const extraKeys = cellKeys.filter(key => !expectedKeys.includes(key));
      if (extraKeys.length > 0) {
        this.errorMessage = `Table Cells has unexpected keys: ${extraKeys.join(', ')}.`;
        return false;
      }
    }
    const headerNames = new Set<string>();
    const headerValues = new Set<string>();
    for (const header of this.dataTableHeaders) {
      if (headerNames.has(header.name) || headerValues.has(header.value)) {
        this.errorMessage = 'You cannot have duplicate headers (either name or value)!';
        return false;
      }
      headerNames.add(header.name);
      headerValues.add(header.value);
    }

    this.errorMessage = null;
    return true;
  }

  constructor(owner: unknown, args: any) {
    super(owner, args);
    if (!this.validateData()) console.error(this.errorMessage);
  }
  @action
  onCellClick(cellData: cellDataType): void {
    this.editInputMode = {
      headerInput: false,
      cellInput: true
    };
    this.editedCell = { cellIndex: cellData.cellIndex, headerIndex: cellData.headerIndex };
    this.editedValue = cellData.value;
  }
  @action
  onHeaderClick(headerData: headerDataType): void {
    this.editInputMode = {
      headerInput: true,
      cellInput: false
    };

    this.editedHeader = headerData.headerIndex;
    this.editedValue = headerData.value;
  }

  @action
  handleKeyDown(event: KeyboardEvent): void {
    if (event.key === "Enter") {
      this.saveEditedValue();
    } else if (event.key === "Escape") {
      this.cancelEdit();
    }
  }
  // created a seperate function to reset editing state
  private resetEditingState(): void {
    this.editedHeader = null;
    this.editedCell = null;
    this.editedValue = '';
  }

  private toCamelCase(input: string): string {
    return input
      .trim()
      .toLowerCase()
      .split(' ')
      .map((word, index) =>
        index === 0 ? word : word.charAt(0).toUpperCase() + word.slice(1)
      )
      .join('');
  }
  @action
  saveEditedValue(): void {
    next(() => {
      // check for empty value
      if(this.editedValue === ''){
        this.errorMessage = 'You cannot leave an empty value!';
        return;
      }
      // only if the edited header has any number more than/equal 0 cause of index and not null
      if(this.editedHeader !== null && this.editedHeader >= 0){
        const header = this.dataTableHeaders[this.editedHeader];
        if(header){
          // check if the value has been changed
          const trimmedEditedValue = this.toCamelCase(this.editedValue);
          const trimmedHeaderName = this.toCamelCase(header.name);
          console.log(this.editedValue)
          if (trimmedHeaderName === this.editedValue) {
            // No changes, exit early
            this.resetEditingState();
            return;
          }
          // store old header value & name for later
          const oldHeaderValue = header.value;
          // check if the new header name or camel case value is duplicated
          const duplicateHeader = this.dataTableHeaders.some((currentHeader, index) => {
            // ignore current header being edited from the duplicate check
            if (index === this.editedHeader) {
              return false;
            }
            const currentHeaderCamelCase = this.toCamelCase(currentHeader.name);
            return (
              currentHeaderCamelCase === trimmedEditedValue ||
              currentHeader.value === trimmedEditedValue
            );
          })
          if (duplicateHeader) {
            this.errorMessage = 'You cannot have a duplicate Header!';
            return;
          }

          set(header, 'name', this.editedValue)
          set(header, 'value', trimmedEditedValue)

          // once new header value is updated with the new camel case
          // it is time to update our cell's key with the new header value
          if (trimmedEditedValue !== oldHeaderValue) {
            this.dataTableCells = this.dataTableCells.map((cell) => {
              // do a temp copy then return with the new updated cell
              const updatedCell = { ...cell };
              // if updatedCell[oldHeaderValue] is either undefined null , return empty
              if (oldHeaderValue in updatedCell) {
                updatedCell[trimmedEditedValue] = updatedCell[oldHeaderValue]  ?? '';
                delete updatedCell[oldHeaderValue];
              }
              return updatedCell;
            });
          }
        }
      }

      if (this.editedCell) {
        const { cellIndex, headerIndex } = this.editedCell;
        const header = this.dataTableHeaders[headerIndex];
        const cell = this.dataTableCells[cellIndex];
        if(cell && header){
          set(cell, header.value, this.editedValue)
        }
      }

      this.dataTableHeaders = [...this.dataTableHeaders];
      this.dataTableCells = [...this.dataTableCells];
      // reset too
      this.resetEditingState()
      if (!this.validateData()) console.error(this.errorMessage);
       this.args.onDataChange?.(this.dataTableHeaders, this.dataTableCells);
    })
  }

  @action
  cancelEdit(): void {
    next(() => {
      this.editedCell = null;
      this.editedHeader = null;
      this.editedValue = '';
      this.editInputMode = {
        headerInput: false,
        cellInput: false
      };

    })
  }

  @action
  updateEditedValue(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.editedValue = input.value;
  }

  <template>
    <div class="data-table" ...attributes>
      {{#if this.errorMessage}}
        <div class="error-message">
          <p>{{this.errorMessage}}</p>
        </div>
      {{/if}}
      <table>
        <thead>
          <tr>
            {{#each this.dataTableHeaders as |header headerIndex|}}
              <th
                id={{concat 'header-' headerIndex}}
                class={{if (and this.editInputMode.headerInput (eq headerIndex this.editedHeader)) "editing"}}
                style={{if header.width (concat 'min-width:' header.width) 'min-width:200px'}}
                data-value={{ header.value}}
                {{on "click" (fn this.onHeaderClick (hash
                  id=(concat 'header-' headerIndex)
                  headerIndex=headerIndex
                  value=header.value
                ))}}>
                {{#if (and this.editInputMode.headerInput (eq headerIndex this.editedHeader))}}
                    <input
                      type="text"
                      value={{header.name}}
                      {{on "input" this.updateEditedValue}}
                      {{on "keydown" this.handleKeyDown}}
                      {{on "blur" this.cancelEdit}}
                    />
                  {{else}}
                    <span>{{header.name}}</span>
                  {{/if}}

              </th>
            {{/each}}
          </tr>
        </thead>
        <tbody>
          {{#each this.dataTableCells as |cell cellIndex|}}
            <tr>
              {{#each this.dataTableHeaders as |header headerIndex|}}
                <td
                  id={{concat 'header-' headerIndex '-cell-' cellIndex }}
                  class={{if (and this.editInputMode.cellInput (eq cellIndex this.editedCell.cellIndex) (eq headerIndex this.editedCell.headerIndex)) "editing"}}
                  data-value={{get cell header.value}}
                  data-parent={{header.value}}
                  {{on "click" (fn this.onCellClick (hash
                    id=(concat 'header-' headerIndex '-cell-' cellIndex)
                    value=(get cell header.value)
                    parent=header.value
                    cellIndex=cellIndex
                    headerIndex=headerIndex
                  ))}}
                >
                  {{#if (and this.editInputMode.cellInput (eq cellIndex this.editedCell.cellIndex) (eq headerIndex this.editedCell.headerIndex))}}
                    <input
                      type="text"
                      value={{get cell header.value}}
                      {{on "input" this.updateEditedValue}}
                      {{on "keydown" this.handleKeyDown}}
                      {{on "blur" this.cancelEdit}}
                    />
                  {{else}}
                    <span>{{get cell header.value}}</span>
                  {{/if}}
                </td>
              {{/each}}
            </tr>
          {{/each}}
        </tbody>
      </table>
    </div>
    <style scoped>
      .error-message {
        color: var(--boxel-error-100);
        font-weight: bold;
        margin-bottom: var(--boxel-sp-sm);
      }
      .data-table {
        max-width:100%;
        overflow:auto;
        width: 100%;
        border-collapse: collapse;
        max-height: clamp(200px, 70dvh, 600px);
      }
      th, td {
        padding: var(--boxel-sp-sm) var(--boxel-sp);
        text-align: left;
        border: var(--boxel-border);
        cursor: pointer;
      }
      .editing{
        padding:0;
      }
      .editing:hover{
        border-color:transparent;
      }
      td:hover {
        box-shadow: var(--boxel-box-shadow-hover);
        background-color: var(--boxel-light-100);
        border-color: var(--boxel-dark);
      }
      input {
        width:100%;
        font-family:var(--boxel-font-family);
        padding: var(--boxel-sp-sm) var(--boxel-sp);
        border:1px solid var(--boxel-highlight);
      }
    </style>
  </template>
}
