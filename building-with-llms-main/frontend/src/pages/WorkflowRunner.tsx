import { useState } from "react";
import { useParams } from "react-router-dom";
import {
  Box,
  VStack as ChakraVStack,
  Heading,
  Textarea,
  Button,
  Text,
  useToast,
  Card,
  CardBody,
} from "@chakra-ui/react";
import Editor from "@monaco-editor/react";

const WorkflowRunner = () => {
  const { id } = useParams();
  const toast = useToast();
  const [input, setInput] = useState("");
  const [output, setOutput] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleRun = async () => {
    if (!input.trim()) {
      toast({
        title: "Input required",
        description: "Please provide input for the workflow",
        status: "error",
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    setIsLoading(true);
    try {
      const response = await fetch(`http://localhost:8000/api/workflow/${id}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ input }),
      });

      const data = await response.json();
      setOutput(JSON.stringify(data, null, 2));
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to run workflow. Please try again.",
        status: "error",
        duration: 3000,
        isClosable: true,
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Box maxW="1400px" mx="auto">
      <ChakraVStack spacing={8} align="stretch">
        <Heading size="xl">Workflow Runner: {id}</Heading>

        <Card>
          <CardBody>
            <Text fontWeight="bold" mb={2}>
              Input:
            </Text>
            <Textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Enter your input here..."
              minH="150px"
              mb={4}
            />
            <Button
              colorScheme="blue"
              onClick={handleRun}
              disabled={isLoading}
              loadingText="Running..."
              width="full"
            >
              Run Workflow
            </Button>
          </CardBody>
        </Card>

        {output && (
          <Card>
            <CardBody>
              <Text fontWeight="bold" mb={2}>
                Output:
              </Text>
              <Box borderRadius="md" overflow="hidden">
                <Editor
                  height="300px"
                  defaultLanguage="json"
                  value={output}
                  options={{
                    readOnly: true,
                    minimap: { enabled: false },
                    scrollBeyondLastLine: false,
                    fontSize: 14,
                    lineNumbers: "on",
                    renderLineHighlight: "none",
                    theme: "vs-light",
                  }}
                />
              </Box>
            </CardBody>
          </Card>
        )}
      </ChakraVStack>
    </Box>
  );
};

export default WorkflowRunner;
