package com.example.demo.controller;

import com.example.demo.model.GreetingResponse;
import com.example.demo.service.GreetingService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class GreetingController {

    private final GreetingService greetingService;

    public GreetingController(GreetingService greetingService) {
        this.greetingService = greetingService;
    }

    @GetMapping("/greeting")
    public GreetingResponse greeting(@RequestParam(defaultValue = "World") String name) {
        return greetingService.greet(name);
    }

    @GetMapping("/health")
    public java.util.Map<String, Object> health() {
        return java.util.Map.of(
                "status", "UP",
                "timestamp", java.time.Instant.now().toString()
        );
    }
}
