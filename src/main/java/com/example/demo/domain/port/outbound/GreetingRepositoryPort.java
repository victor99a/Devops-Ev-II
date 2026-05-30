package com.example.demo.domain.port.outbound;

import com.example.demo.domain.model.Greeting;

import java.util.List;
import java.util.Optional;

public interface GreetingRepositoryPort {
    Greeting save(Greeting greeting);

    List<Greeting> findAll();

    Optional<Greeting> findById(Long id);
}
