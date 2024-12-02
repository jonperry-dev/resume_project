import React, { useState } from "react";
import styled from "styled-components";
import * as pdfjsLib from "pdfjs-dist";
import { theme } from "./theme";
import axios from "axios";

pdfjsLib.GlobalWorkerOptions.workerSrc = "/pdf.worker.min.js";

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

const MISSING_FILE_URL =
  "A resume must be uploaded in .pdf format and provide a URL to a job posting.";
const MISSING_FILE = "A resume must be uploaded in .pdf format.";
const MISSING_URL = "Provide a valid URL to a job posting.";

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
  display: absolute;
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
  position: absolute;
  top: -25px;
  left: 0;
  color: red;
  font-size: 0.9em;
  padding: 5px 10px;
  border-radius: 4px;
  background-color: #ffe6e6;
  opacity: ${({ show }) => (show ? 1 : 0)};
  transform: ${({ show }) => (show ? "translateY(0)" : "translateY(10px)")};
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

const MessageText = styled.div`
  flex: 1; /* Allow the text container to expand */
  background: ${({ isBot }) =>
    isBot ? theme.colors.secondary : theme.colors.secondary};
  padding: 10px 15px;
  border-radius: 10px;
  max-width: 70%;
  word-wrap: break-word; /* Ensure long words break properly */
  white-space: pre-line; /* Preserve line breaks */
  font-size: 1em;
  line-height: 1.5; /* Improve readability */

  @media (max-width: 768px) {
    max-width: 90%;
    font-size: 0.9em; /* Adjust font size for mobile */
    padding: 8px 12px;
  }
`;

const MessageContainer = styled.div`
  display: flex;
  align-items: flex-start;
  gap: 10px;
  flex-direction: ${({ isBot }) =>
    isBot
      ? "row"
      : "row-reverse"}; /* Bot messages align left, user messages right */

  @media (max-width: 768px) {
    gap: 8px; /* Reduce gap for smaller screens */
  }
`;

const Avatar = styled.div`
  flex-shrink: 0; /* Prevent avatar from shrinking */
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

  @media (max-width: 768px) {
    width: 35px; /* Slightly smaller avatar for mobile */
    height: 35px;
  }
`;

const Chatbot = () => {
  const [messages, setMessages] = useState([]);
  const [pdfText, setPdfText] = useState([]);
  const [file, setFile] = useState(null);
  const [textInput, setInput] = useState("");
  const [error, setError] = useState("");
  const [response, setResponse] = useState(null);

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
      setPdfText(extractedText);
    };

    fileReader.readAsArrayBuffer(file);
  };

  const handleSendMessage = async () => {
    if (textInput.trim() && file && isValidUrl(textInput)) {
      setMessages((prev) => [
        ...prev,
        {
          text: "Please review and rank this job with my resume: " + textInput,
          isBot: false,
        },
        { text: "Let me take a look!", isBot: true },
      ]);
      setInput("");
      setFile(null);
      setError("");
      const endpoint = process.env.REACT_APP_RANK_ENDPOINT;
      const apiKey = process.env.REACT_APP_RANK_API_KEY;
      const requestData = {
        url: textInput,
        resume: pdfText,
      };
      const result = await axios.post(endpoint, requestData, {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
      });
      const botResp =
        "The job posting for " +
        result.data["positionTitle"] +
        " at " +
        result.data["companyName"];
      const botResp2 =
        "has a ranking of " +
        `${(result.data["rank"] * 100).toFixed(2)}%` +
        "!\n";
      const botResp3 =
        "\nHere is some feedback from me:\n" + result.data["feedback"];
      const fullResponse = `${botResp} ${botResp2} ${botResp3}`;
      console.log("Result: ", botResp + botResp2 + botResp3);
      setMessages((prev) => [...prev, { text: fullResponse, isBot: true }]);
    } else if (!isValidUrl(textInput) && !file) {
      setError(MISSING_FILE_URL);
    } else if (!file && isValidUrl(textInput)) {
      setError(MISSING_FILE);
    } else if (file && !isValidUrl(textInput)) {
      setError(MISSING_URL);
    }
  };

  const handleInputChange = (e) => {
    const value = e.target.value;
    setInput(value);

    if (!isValidUrl(value) && !file) {
      setError(MISSING_FILE_URL);
    } else if (file && !isValidUrl(value)) {
      setError(MISSING_URL);
    } else {
      setError("");
    }
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
      setError(error.concat("Only PDF files are allowed."));
      setFile(null);
    }
  };

  const handleKeyDown = async (event) => {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault(); // Prevent newline
      await handleSendMessage();
    } else if (event.key === "Enter" && event.shiftKey) {
      event.preventDefault();
    }
  };

  return (
    <FullScreenChat>
      <ChatHeader>ResumeAI Ranker</ChatHeader>
      <ChatWindow>
        {messages.map((message, index) => (
          <MessageContainer key={index} isBot={message.isBot}>
            <Avatar isBot={message.isBot}>{message.isBot ? "B" : "U"}</Avatar>
            <MessageText>{message.text}</MessageText>
          </MessageContainer>
        ))}
      </ChatWindow>
      <ChatInputSection>
        <InputFieldContainer>
          <InputRow>
            <ErrorMessage show={!!error}>{error}</ErrorMessage>
            <InputField
              rows="1"
              value={textInput}
              onKeyDown={handleKeyDown}
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
              disabled={!textInput.trim() || !file || error}
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
