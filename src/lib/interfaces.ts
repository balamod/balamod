export interface Balatro {
  path: string;
  version: string;
}

export type Balatros = Record<string, Balatro>;

export interface IBalatroPageData {
  balatro: Balatro;
  defaultOutput: string;
}

export interface IDataError {
  error: string;
}
