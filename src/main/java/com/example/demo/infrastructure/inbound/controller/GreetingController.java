package com.example.demo.infrastructure.inbound.controller;

import com.example.demo.domain.model.Greeting;
import com.example.demo.domain.port.inbound.CreateGreetingUseCase;
import com.example.demo.domain.port.inbound.LifecycleUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/greetings")
public class GreetingController {

    private final CreateGreetingUseCase createGreetingUseCase;
    private final LifecycleUseCase lifecycleUseCase;

    public GreetingController(CreateGreetingUseCase createGreetingUseCase, LifecycleUseCase lifecycleUseCase) {
        this.createGreetingUseCase = createGreetingUseCase;
        this.lifecycleUseCase = lifecycleUseCase;
    }

    @GetMapping
    public List<Greeting> findAll() {
        return lifecycleUseCase.findAllGreetings();
    }

    @PostMapping
    public ResponseEntity<Greeting> create(@RequestParam(defaultValue = "World") String name) {
        Greeting greeting = createGreetingUseCase.createGreeting(name);
        return ResponseEntity.status(HttpStatus.CREATED).body(greeting);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Greeting> findById(@PathVariable Long id) {
        return lifecycleUseCase.findGreetingById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
