package com.example.demo.domain.port.inbound;

import com.example.demo.domain.model.Greeting;

public interface CreateGreetingUseCase {
    Greeting createGreeting(String name);
}
