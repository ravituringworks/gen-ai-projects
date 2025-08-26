import { ChakraProvider, Box } from "@chakra-ui/react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Navbar from "./components/Navbar";
import Home from "./pages/Home";
import WorkflowRunner from "./pages/WorkflowRunner";
import AgentRunner from "./pages/AgentRunner";
import { theme } from "@chakra-ui/theme";

function App() {
  return (
    <ChakraProvider theme={theme}>
      <Router>
        <Box minH="100vh" w="100vw" bg="gray.50">
          <Navbar />
          <Box w="full" py={8} px={4}>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/workflow/:id" element={<WorkflowRunner />} />
              <Route path="/agent/:id" element={<AgentRunner />} />
            </Routes>
          </Box>
        </Box>
      </Router>
    </ChakraProvider>
  );
}

export default App;
