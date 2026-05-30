package com.example.demo.infrastructure.outbound.database;

import com.example.demo.domain.model.Greeting;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GreetingRepositoryAdapterTest {

    @Mock
    private SpringGreetingRepository springGreetingRepository;

    @InjectMocks
    private GreetingRepositoryAdapter adapter;

    @Nested
    @DisplayName("save(Greeting)")
    class Save {

        @Test
        @DisplayName("persists greeting and returns domain entity with id")
        void shouldPersistGreetingAndReturnDomainEntityWithId() {
            Greeting domain = new Greeting(null, "Duoc", "Hello, Duoc!", Instant.now());
            GreetingEntity savedEntity = new GreetingEntity("Duoc", "Hello, Duoc!", domain.timestamp());
            savedEntity.setId(1L);

            when(springGreetingRepository.save(any())).thenReturn(savedEntity);

            Greeting result = adapter.save(domain);

            assertThat(result.id()).isEqualTo(1L);
            assertThat(result.name()).isEqualTo("Duoc");
            assertThat(result.message()).isEqualTo("Hello, Duoc!");
            assertThat(result.timestamp()).isEqualTo(domain.timestamp());
        }
    }

    @Nested
    @DisplayName("findAll()")
    class FindAll {

        @Test
        @DisplayName("returns empty list when no entities exist")
        void shouldReturnEmptyListWhenNoEntitiesExist() {
            when(springGreetingRepository.findAll()).thenReturn(List.of());

            List<Greeting> result = adapter.findAll();

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("returns list of domain entities")
        void shouldReturnListOfDomainEntities() {
            GreetingEntity entity = new GreetingEntity("Duoc", "Hello, Duoc!", Instant.now());
            entity.setId(1L);
            when(springGreetingRepository.findAll()).thenReturn(List.of(entity));

            List<Greeting> result = adapter.findAll();

            assertThat(result).hasSize(1);
            assertThat(result.get(0).id()).isEqualTo(1L);
            assertThat(result.get(0).name()).isEqualTo("Duoc");
        }
    }

    @Nested
    @DisplayName("findById(Long)")
    class FindById {

        @Test
        @DisplayName("returns domain entity when found")
        void shouldReturnDomainEntityWhenFound() {
            GreetingEntity entity = new GreetingEntity("Duoc", "Hello, Duoc!", Instant.now());
            entity.setId(1L);
            when(springGreetingRepository.findById(1L)).thenReturn(Optional.of(entity));

            Optional<Greeting> result = adapter.findById(1L);

            assertThat(result).isPresent();
            assertThat(result.get().id()).isEqualTo(1L);
            assertThat(result.get().name()).isEqualTo("Duoc");
        }

        @Test
        @DisplayName("returns empty when not found")
        void shouldReturnEmptyWhenNotFound() {
            when(springGreetingRepository.findById(99L)).thenReturn(Optional.empty());

            Optional<Greeting> result = adapter.findById(99L);

            assertThat(result).isEmpty();
        }
    }
}
