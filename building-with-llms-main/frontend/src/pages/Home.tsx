import {
  Box,
  Grid,
  Heading,
  Text,
  Card as ChakraCard,
  CardBody,
  Stack as ChakraStack,
  Button,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";

const workflows = [
  {
    id: "text-analysis",
    name: "Text Analysis",
    description: "Sequential LLM calls with intermediate processing",
    category: "workflow",
  },
  {
    id: "support-routing",
    name: "Support Routing",
    description: "Input classification and specialized handling",
    category: "workflow",
  },
  {
    id: "content-moderation",
    name: "Content Moderation",
    description: "Concurrent LLM processing with sectioning and voting",
    category: "workflow",
  },
  {
    id: "document-processing",
    name: "Document Processing",
    description: "Dynamic task decomposition and delegation",
    category: "workflow",
  },
  {
    id: "code-optimization",
    name: "Code Optimization",
    description: "Iterative improvement through feedback loops",
    category: "workflow",
  },
];

const agents = [
  {
    id: "research-assistant",
    name: "Research Assistant",
    description: "Self-directed system with planning and execution",
    category: "agent",
  },
  {
    id: "medical-assistant",
    name: "Medical Assistant",
    description: "Domain-specific agent for medical diagnosis",
    category: "agent",
  },
];

const Home = () => {
  const navigate = useNavigate();

  const handleItemClick = (
    item: (typeof workflows)[0] | (typeof agents)[0]
  ) => {
    navigate(`/${item.category}/${item.id}`);
  };

  return (
    <Box maxW="1400px" mx="auto">
      <ChakraStack spacing={12}>
        <Box>
          <Heading size="xl" mb={8}>
            Workflows
          </Heading>
          <Grid templateColumns="repeat(auto-fill, minmax(320px, 1fr))" gap={6}>
            {workflows.map((workflow) => (
              <ChakraCard
                key={workflow.id}
                cursor="pointer"
                onClick={() => handleItemClick(workflow)}
                transition="all 0.2s"
                _hover={{ transform: "translateY(-4px)", shadow: "lg" }}
              >
                <CardBody>
                  <Heading size="md" mb={2}>
                    {workflow.name}
                  </Heading>
                  <Text color="gray.600" mb={4}>
                    {workflow.description}
                  </Text>
                  <Button size="sm" colorScheme="blue" width="full">
                    Try it out
                  </Button>
                </CardBody>
              </ChakraCard>
            ))}
          </Grid>
        </Box>

        <Box>
          <Heading size="xl" mb={8}>
            Agents
          </Heading>
          <Grid templateColumns="repeat(auto-fill, minmax(320px, 1fr))" gap={6}>
            {agents.map((agent) => (
              <ChakraCard
                key={agent.id}
                cursor="pointer"
                onClick={() => handleItemClick(agent)}
                transition="all 0.2s"
                _hover={{ transform: "translateY(-4px)", shadow: "lg" }}
              >
                <CardBody>
                  <Heading size="md" mb={2}>
                    {agent.name}
                  </Heading>
                  <Text color="gray.600" mb={4}>
                    {agent.description}
                  </Text>
                  <Button size="sm" colorScheme="green" width="full">
                    Try it out
                  </Button>
                </CardBody>
              </ChakraCard>
            ))}
          </Grid>
        </Box>
      </ChakraStack>
    </Box>
  );
};

export default Home;
