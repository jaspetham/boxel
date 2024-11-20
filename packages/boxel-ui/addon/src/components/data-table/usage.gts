import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import FreestyleUsage from 'ember-freestyle/components/freestyle/usage';
import DataTable, { DataTableHeader, DataTableCell } from './index.gts';

export default class DataTableUsage extends Component {
  @tracked private tableDataHeaders:DataTableHeader[] =  [
    {
      "name": "First Name",
      "value": "firstName"
    },
    {
      "name": "Last Name",
      "value": "lastName"
    },
    {
      "name": "Email",
      "value": "email"
    }
  ]
  @tracked private tableDataCells:DataTableCell[] = [
    {
      "firstName": "John",
      "lastName": "Doe",
      "email": "john.doe@example.com"
    },

    {
      "firstName": "Jane",
      "lastName": "Smith",
      "email": "jane.smith@example.com"
    },

    {
      "firstName": "Emily",
      "lastName": "Dane",
      "email": "emily.davis@example.com",
    }
  ]

  // better add a listener to update the latest table data
  @action
  onDataChange(updatedHeaders: DataTableHeader[], updatedCells: DataTableCell[]): void {
    this.tableDataHeaders = updatedHeaders;
    this.tableDataCells = updatedCells;
  }

  constructor(owner: unknown, args: any) {
    super(owner, args);
  }

  <template>
    <FreestyleUsage @name='Data Table'>
      <:description>
        <p>A Data table that can send in two array of data consisting of Headers & Cells that can be edited when on click. </p>
        <p>There will be also a validation check for if the key value is missing from the header's provided key</p>
      </:description>
      <:example>
        <DataTable
          @tableHeaders={{this.tableDataHeaders}}
          @tableCells={{this.tableDataCells}}
          @onDataChange={{this.onDataChange}}/>
      </:example>
      <:api as |Args|>
        <Args.Object
          @name='Data Table Headers'
          @description="An array of data objects for the header, the object value has to be as the following 'name' & 'value' as key "
          @value={{this.tableDataHeaders}}
        />
        <Args.Object
          @name='Data Table Cells'
          @description='An array of data objects for the cell, the object value can be whatever the header value'
          @value={{this.tableDataCells}}
        />
      </:api>
    </FreestyleUsage>
  </template>
}
