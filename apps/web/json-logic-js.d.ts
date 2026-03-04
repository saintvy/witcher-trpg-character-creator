declare module 'json-logic-js' {
  type JsonLogicRule = unknown;
  interface JsonLogic {
    apply<T = unknown, Data = Record<string, unknown>>(rule: JsonLogicRule, data?: Data): T;
    add_operation(name: string, operation: (...args: unknown[]) => unknown): void;
    add_operation(operations: Record<string, (...args: unknown[]) => unknown>): void;
    rm_operation(name: string): void;
  }
  const jsonLogic: JsonLogic;
  export default jsonLogic;
}

