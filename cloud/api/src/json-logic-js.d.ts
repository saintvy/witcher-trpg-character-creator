declare module 'json-logic-js' {
  export type RulesLogic<AdditionalOperation = never> = unknown & {
    __additionalOperation?: AdditionalOperation;
  };

  interface JsonLogic {
    apply<T = unknown, Data = Record<string, unknown>>(
      rule: RulesLogic,
      data?: Data,
    ): T;
    add_operation(name: string, operation: (...args: unknown[]) => unknown): void;
    add_operation(operations: Record<string, (...args: unknown[]) => unknown>): void;
    rm_operation(name: string): void;
  }

  const jsonLogic: JsonLogic;
  export default jsonLogic;
}

