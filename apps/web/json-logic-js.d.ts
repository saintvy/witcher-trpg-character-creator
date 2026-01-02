declare module 'json-logic-js' {
  type JsonLogicRule = unknown;
  interface JsonLogic {
    apply<T = unknown, Data = Record<string, unknown>>(rule: JsonLogicRule, data?: Data): T;
  }
  const jsonLogic: JsonLogic;
  export default jsonLogic;
}

