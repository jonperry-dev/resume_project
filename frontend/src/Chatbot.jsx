import React, { useState } from "react";
import styled from "styled-components";
import { theme } from "./theme";

const hexToRgba = (hex, alpha) => {
  const match = hex
    .replace("#", "")
    .match(/.{1,2}/g)
    .map((x) => parseInt(x, 16));
  return `rgba(${match[0]}, ${match[1]}, ${match[2]}, ${alpha})`;
};

const FullScreenChat = styled.div`
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: ${(props) => props.theme.colors.background};
  font-family: Arial, sans-serif;
`;

const ChatHeader = styled.div`
  background: ${(props) => props.theme.colors.primary};
  color: ${(props) => props.theme.colors.textLight};
  padding: 10px 20px;
  font-size: 1.5em;
  text-align: center;
`;

const ChatWindow = styled.div`
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 10px;
`;

const ChatInputSection = styled.div`
  display: flex;
  align-items: center;
  padding: 10px;
  background: ${(props) => hexToRgba(props.theme.colors.primary, 0.8)};
  border-top: 3px solid ${(props) => props.theme.colors.secondary};
`;

const InputField = styled.textarea`
  flex: 1;
  border: 1px solid ${(props) => props.theme.colors.secondary};
  background: ${(props) => props.theme.colors.background};
  border-radius: 5px;
  padding: 10px;
  font-size: 1em;
  resize: none;
`;

const SendButton = styled.button`
  margin-left: 10px;
  padding: 10px 20px;
  background: ${(props) => props.theme.colors.accent};
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
`;

const FileUploadButton = styled.label`
  margin-left: 10px;
  padding: 10px 20px;
  background: ${(props) => props.theme.colors.primary};
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
`;

const Message = styled.div`
  display: flex;
  align-items: center;
  max-width: 70%;
  padding: 10px;
  border-radius: 10px;
  background: ${({ isBot }) =>
    isBot ? theme.colors.secondary : theme.colors.secondary};
  align-self: ${({ isBot }) => (isBot ? "flex-start" : "flex-end")};
`;

const Avatar = styled.div`
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: ${({ isBot }) =>
    isBot ? theme.colors.primary : theme.colors.primary};
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  margin-right: 10px;
`;

const Chatbot = () => {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");

  const handleSendMessage = () => {
    if (input.trim()) {
      setMessages([...messages, { text: input, isBot: false }]);
      setInput("");
      setTimeout(() => {
        setMessages((prev) => [
          ...prev,
          { text: "This is a bot response.", isBot: true },
        ]);
      }, 1000);
    }
  };

  const handleFileUpload = (event) => {
    const file = event.target.files[0];
    if (file) {
      setMessages([
        ...messages,
        { text: `Uploaded: ${file.name}`, isBot: false },
      ]);
    }
  };

  const handleKeyDown = (event) => {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault(); // Prevent newline
      handleSendMessage();
    }
  };

  return (
    <FullScreenChat>
      <ChatHeader>ResumeAI Ranker</ChatHeader>
      <ChatWindow>
        {messages.map((message, index) => (
          <Message key={index} isBot={message.isBot}>
            <Avatar isBot={message.isBot}>{message.isBot ? "B" : "U"}</Avatar>
            {message.text}
          </Message>
        ))}
      </ChatWindow>
      <ChatInputSection>
        <InputField
          rows="1"
          value={input}
          onKeyDown={handleKeyDown}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type a message..."
        />
        <SendButton onClick={handleSendMessage}>Send</SendButton>
        <FileUploadButton>
          Upload
          <input
            type="file"
            style={{ display: "none" }}
            onChange={handleFileUpload}
          />
        </FileUploadButton>
      </ChatInputSection>
    </FullScreenChat>
  );
};

export default Chatbot;
