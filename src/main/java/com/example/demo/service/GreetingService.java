package com.example.demo.service;

import com.example.demo.model.GreetingResponse;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class GreetingService {

    public GreetingResponse greet(String name) {
        if (name == null || name.isBlank()) {
            name = "World";
        }
        String message = "Hello, " + name + "!";
        return new GreetingResponse(message, name, Instant.now());
    }
}
