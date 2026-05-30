package com.example.demo.infrastructure.outbound.database;

import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringGreetingRepository extends JpaRepository<GreetingEntity, Long> {
}
