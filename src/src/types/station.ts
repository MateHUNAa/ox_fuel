export type Fuel = {
  fuel: number;
  type: string;
};

export interface Station {
  Fuels: Fuel[];
  income: number;
  tax: number;
  stationName: string;
}
