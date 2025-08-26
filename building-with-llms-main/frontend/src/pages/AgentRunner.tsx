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

interface Message {
  role: "user" | "agent";
  content: string;
  timestamp: string;
}

const AgentRunner = () => {
  const { id } = useParams();
  const toast = useToast();
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const handleSend = async () => {
    if (!input.trim()) {
      toast({
        title: "Input required",
        description: "Please provide input for the agent",
        status: "error",
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    const userMessage: Message = {
      role: "user",
      content: input,
      timestamp: new Date().toISOString(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setIsLoading(true);

    try {
      const response = await fetch(`http://localhost:8000/api/agent/${id}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: input }),
      });

      const data = await response.json();
      const agentMessage: Message = {
        role: "agent",
        content: data.response,
        timestamp: new Date().toISOString(),
      };

      setMessages((prev) => [...prev, agentMessage]);
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to get response from agent. Please try again.",
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
        <Heading size="xl">Agent Runner: {id}</Heading>

        <Card>
          <CardBody>
            <Box
              minH="400px"
              maxH="600px"
              overflowY="auto"
              mb={4}
              sx={{
                "&::-webkit-scrollbar": {
                  width: "8px",
                  borderRadius: "8px",
                  backgroundColor: "gray.100",
                },
                "&::-webkit-scrollbar-thumb": {
                  backgroundColor: "gray.300",
                  borderRadius: "8px",
                },
              }}
            >
              {messages.map((message, index) => (
                <Box
                  key={index}
                  mb={4}
                  p={4}
                  bg={message.role === "user" ? "blue.50" : "green.50"}
                  borderRadius="lg"
                  boxShadow="sm"
                >
                  <Text fontWeight="bold" mb={2}>
                    {message.role === "user" ? "You" : "Agent"}:
                  </Text>
                  <Text whiteSpace="pre-wrap">{message.content}</Text>
                  <Text fontSize="xs" color="gray.500" mt={2}>
                    {new Date(message.timestamp).toLocaleTimeString()}
                  </Text>
                </Box>
              ))}
            </Box>

            <Textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Type your message here..."
              minH="100px"
              mb={4}
            />
            <Button
              colorScheme="green"
              onClick={handleSend}
              disabled={isLoading}
              loadingText="Sending..."
              width="full"
            >
              Send Message
            </Button>
          </CardBody>
        </Card>
      </ChakraVStack>
    </Box>
  );
};

export default AgentRunner;
