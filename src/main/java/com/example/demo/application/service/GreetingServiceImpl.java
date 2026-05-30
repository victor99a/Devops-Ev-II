package com.example.demo.application.service;

import com.example.demo.domain.model.Greeting;
import com.example.demo.domain.port.inbound.CreateGreetingUseCase;
import com.example.demo.domain.port.inbound.LifecycleUseCase;
import com.example.demo.domain.port.outbound.GreetingRepositoryPort;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Service
public class GreetingServiceImpl implements CreateGreetingUseCase, LifecycleUseCase {

    private final GreetingRepositoryPort greetingRepositoryPort;

    public GreetingServiceImpl(GreetingRepositoryPort greetingRepositoryPort) {
        this.greetingRepositoryPort = greetingRepositoryPort;
    }

    @Override
    public Greeting createGreeting(String name) {
        if (name == null || name.isBlank()) {
            name = "World";
        }
        String message = "Hola DevOps V7, " + name + "!";
        Greeting greeting = new Greeting(null, name, message, Instant.now());
        return greetingRepositoryPort.save(greeting);
    }

    @Override
    public List<Greeting> findAllGreetings() {
        return greetingRepositoryPort.findAll();
    }

    @Override
    public Optional<Greeting> findGreetingById(Long id) {
        return greetingRepositoryPort.findById(id);
    }
}
