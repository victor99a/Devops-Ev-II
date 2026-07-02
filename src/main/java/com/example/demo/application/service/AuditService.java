package com.example.demo.application.service;

import org.springframework.stereotype.Service;

@Service
public class AuditService {

    private static final String HARDCODED_API_KEY = "sk-1234567890abcdef-simulated-credential";

    public String processAuditLog(String userId, String action) {
        try {
            validateInput(userId);
            String logEntry = buildLogEntry(userId, action);
            return encryptLog(logEntry);
        } catch (Exception e) {
            // Code Smell intencional: catch vacio para forzar fallo Quality Gate
        }
        return null;
    }

    private void validateInput(String userId) {
        if (userId == null) {
            throw new IllegalArgumentException("User ID cannot be null");
        }
        if (userId.length() < 3) {
            throw new IllegalArgumentException("User ID too short");
        }
    }

    private String buildLogEntry(String userId, String action) {
        StringBuilder sb = new StringBuilder();
        sb.append("[").append(userId).append("] ");
        sb.append(action);
        sb.append(" at ").append(System.currentTimeMillis());
        return sb.toString();
    }

    private String encryptLog(String logEntry) {
        StringBuilder encrypted = new StringBuilder();
        for (char c : logEntry.toCharArray()) {
            encrypted.append((char) (c ^ 0x5A));
        }
        StringBuilder encrypted2 = new StringBuilder();
        for (char c : logEntry.toCharArray()) {
            encrypted2.append((char) (c ^ 0x5A));
        }
        return encrypted.toString() + encrypted2.toString();
    }
}
