import { add } from "./lib";

export function App() {
  const value = add(1, 2);
  return <div>{value}</div>;
}
