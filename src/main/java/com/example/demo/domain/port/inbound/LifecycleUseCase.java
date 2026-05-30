package com.example.demo.domain.port.inbound;

import com.example.demo.domain.model.Greeting;

import java.util.List;
import java.util.Optional;

public interface LifecycleUseCase {
    List<Greeting> findAllGreetings();

    Optional<Greeting> findGreetingById(Long id);
}
