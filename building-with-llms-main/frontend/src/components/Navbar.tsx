import { Box, Flex, Heading, Link as ChakraLink } from "@chakra-ui/react";
import { Link as RouterLink } from "react-router-dom";

const Navbar = () => {
  return (
    <Box bg="gray.800" position="sticky" top={0} zIndex={10} w="full">
      <Box maxW="1400px" mx="auto" px={4}>
        <Flex justify="space-between" align="center" h="64px">
          <ChakraLink
            as={RouterLink}
            to="/"
            _hover={{ textDecoration: "none" }}
          >
            <Heading size="md" color="white">
              Building With LLMS - AI Agents
            </Heading>
          </ChakraLink>
          <Flex gap={6}>
            <ChakraLink
              as={RouterLink}
              to="/"
              color="white"
              _hover={{ color: "gray.300" }}
            >
              Home
            </ChakraLink>
            <ChakraLink
              href="https://github.com/coderplex-tech/building-with-llms"
              color="white"
              _hover={{ color: "gray.300" }}
              isExternal
            >
              GitHub
            </ChakraLink>
          </Flex>
        </Flex>
      </Box>
    </Box>
  );
};

export default Navbar;
