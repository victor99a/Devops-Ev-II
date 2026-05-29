package com.example.demo.model;

import java.time.Instant;

public record GreetingResponse(String message, String name, Instant timestamp) {
}
