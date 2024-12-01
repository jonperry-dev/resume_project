import { ThemeProvider } from "styled-components";
import GlobalStyles from "./GlobalStyles";
import { theme } from "./theme";
import Chatbot from "./Chatbot";

const App = () => {
  return (
    <ThemeProvider theme={theme}>
      <GlobalStyles />
      <Chatbot />
    </ThemeProvider>
  );
};

export default App;
