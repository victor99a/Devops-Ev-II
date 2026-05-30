package com.example.demo.domain.model;

import java.time.Instant;

public record Greeting(Long id, String name, String message, Instant timestamp) {
}
