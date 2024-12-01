import React, { useState } from "react";
import styled from "styled-components";
import * as pdfjsLib from "pdfjs-dist";
import { theme } from "./theme";

const hexToRgba = (hex, alpha) => {
  const match = hex
    .replace("#", "")
    .match(/.{1,2}/g)
    .map((x) => parseInt(x, 16));
  return `rgba(${match[0]}, ${match[1]}, ${match[2]}, ${alpha})`;
};

const isValidUrl = (url) => {
  try {
    new URL(url);
    return true;
  } catch (err) {
    return false;
  }
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

const InputFieldContainer = styled.div`
  display: flex;
  flex-direction: column;
  width: 100%;
  position: relative;
`;

const InputRow = styled.div`
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  position: relative;
`;

const InputField = styled.textarea`
  flex: 1;
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 10px;
  font-size: 1em;
  resize: none;
`;

const ErrorMessage = styled.div`
  color: red;
  font-size: 0.9em;
  padding: 5px;
  border: 1px solid red;
  border-radius: 4px;
  background-color: #ffe6e6;
  position: absolute;
  top: -40px;
  left: 0;
  width: 100%;
  opacity: ${({ show }) => (show ? 1 : 0)};
  transform: ${({ show }) => (show ? "translateY(0)" : "translateY(20px)")};
  transition:
    opacity 0.3s ease,
    transform 0.3s ease;
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
  const [pdf, setPdf] = useState([]);
  const [file, setFile] = useState(null);
  const [isUrlValid, setIsUrlValid] = useState(false);
  const [input, setInput] = useState("");
  const [error, setError] = useState("");

  const parsePdf = async (file) => {
    const fileReader = new FileReader();

    fileReader.onload = async (e) => {
      const typedArray = new Uint8Array(e.target.result);
      const pdf = await pdfjsLib.getDocument(typedArray).promise;

      let extractedText = "";
      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const textContent = await page.getTextContent();
        extractedText += textContent.items.map((item) => item.str).join(" ");
      }

      console.log("Extracted text:", extractedText);
      setPdf(extractedText);
    };

    fileReader.readAsArrayBuffer(file);
  };

  const handleSendMessage = () => {
    if (input.trim() && file && isValidUrl(input)) {
      setMessages([...messages, { text: input, isBot: false }]);
      setInput("");
      setFile(null);
      setError("");
      setTimeout(() => {
        setMessages((prev) => [
          ...prev,
          { text: "This is a bot response.", isBot: true },
        ]);
      }, 1000);
    } else if (!isValidUrl(input)) {
      setError("Please enter a valid URL.");
    } else if (!file) {
      setError("A file must be uploaded.");
    }
  };

  const handleInputChange = (e) => {
    const value = e.target.value;
    setInput(value);
    setIsUrlValid(isValidUrl(value)); // Update URL validation state
  };

  const handleFileUpload = (event) => {
    const uploadedFile = event.target.files[0];

    // Validate file type
    if (uploadedFile && uploadedFile.type === "application/pdf") {
      setError("");
      setFile(uploadedFile);

      // Parse the file if needed
      parsePdf(uploadedFile);
    } else {
      setError("Only PDF files are allowed.");
      setFile(null);
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
        <InputFieldContainer>
          <InputRow>
            <ErrorMessage show={!!error}>{error}</ErrorMessage>
            <InputField
              rows="1"
              value={input}
              onChange={handleInputChange}
              placeholder="Enter a URL..."
              className="input-field"
            />
            <FileUploadButton>
              Upload Resume
              <input
                type="file"
                style={{ display: "none" }}
                onChange={handleFileUpload}
                accept=".pdf"
              />
            </FileUploadButton>
            <SendButton
              onClick={handleSendMessage}
              className="send-button"
              disabled={!input.trim() || !file || error}
            >
              Send
            </SendButton>
          </InputRow>
        </InputFieldContainer>
      </ChatInputSection>
    </FullScreenChat>
  );
};

export default Chatbot;
