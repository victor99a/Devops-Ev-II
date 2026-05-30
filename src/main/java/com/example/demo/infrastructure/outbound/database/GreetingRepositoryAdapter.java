package com.example.demo.infrastructure.outbound.database;

import com.example.demo.domain.model.Greeting;
import com.example.demo.domain.port.outbound.GreetingRepositoryPort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
public class GreetingRepositoryAdapter implements GreetingRepositoryPort {

    private final SpringGreetingRepository springGreetingRepository;

    public GreetingRepositoryAdapter(SpringGreetingRepository springGreetingRepository) {
        this.springGreetingRepository = springGreetingRepository;
    }

    @Override
    public Greeting save(Greeting greeting) {
        GreetingEntity entity = toEntity(greeting);
        GreetingEntity saved = springGreetingRepository.save(entity);
        return toDomain(saved);
    }

    @Override
    public List<Greeting> findAll() {
        return springGreetingRepository.findAll()
                .stream()
                .map(this::toDomain)
                .toList();
    }

    @Override
    public Optional<Greeting> findById(Long id) {
        return springGreetingRepository.findById(id)
                .map(this::toDomain);
    }

    private GreetingEntity toEntity(Greeting greeting) {
        return new GreetingEntity(greeting.name(), greeting.message(), greeting.timestamp());
    }

    private Greeting toDomain(GreetingEntity entity) {
        return new Greeting(entity.getId(), entity.getName(), entity.getMessage(), entity.getCreatedAt());
    }
}
