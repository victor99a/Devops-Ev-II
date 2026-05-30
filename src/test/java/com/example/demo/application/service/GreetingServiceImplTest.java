package com.example.demo.application.service;

import com.example.demo.domain.model.Greeting;
import com.example.demo.domain.port.outbound.GreetingRepositoryPort;
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
class GreetingServiceImplTest {

    @Mock
    private GreetingRepositoryPort greetingRepositoryPort;

    @InjectMocks
    private GreetingServiceImpl greetingService;

    @Nested
    @DisplayName("createGreeting(String name)")
    class CreateGreeting {

        @Test
        @DisplayName("returns greeting with given name")
        void shouldCreateGreetingWithGivenName() {
            when(greetingRepositoryPort.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

            Greeting result = greetingService.createGreeting("Duoc");

            assertThat(result.name()).isEqualTo("Duoc");
            assertThat(result.message()).contains("Duoc");
            assertThat(result.timestamp()).isNotNull();
            assertThat(result.id()).isNull();
        }

        @Test
        @DisplayName("falls back to World when name is null")
        void shouldFallbackToWorldWhenNameIsNull() {
            when(greetingRepositoryPort.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

            Greeting result = greetingService.createGreeting(null);

            assertThat(result.name()).isEqualTo("World");
            assertThat(result.message()).contains("World");
            assertThat(result.timestamp()).isNotNull();
        }

        @Test
        @DisplayName("falls back to World when name is blank")
        void shouldFallbackToWorldWhenNameIsBlank() {
            when(greetingRepositoryPort.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

            Greeting result = greetingService.createGreeting("   ");

            assertThat(result.name()).isEqualTo("World");
            assertThat(result.message()).contains("World");
            assertThat(result.timestamp()).isNotNull();
        }

        @Test
        @DisplayName("falls back to World when name is empty string")
        void shouldFallbackToWorldWhenNameIsEmpty() {
            when(greetingRepositoryPort.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

            Greeting result = greetingService.createGreeting("");

            assertThat(result.name()).isEqualTo("World");
            assertThat(result.message()).contains("World");
            assertThat(result.timestamp()).isNotNull();
        }
    }

    @Nested
    @DisplayName("findAllGreetings()")
    class FindAllGreetings {

        @Test
        @DisplayName("returns empty list when no greetings exist")
        void shouldReturnEmptyListWhenNoGreetingsExist() {
            when(greetingRepositoryPort.findAll()).thenReturn(List.of());

            List<Greeting> result = greetingService.findAllGreetings();

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("returns list of greetings")
        void shouldReturnListOfGreetings() {
            Greeting greeting = new Greeting(1L, "Duoc", "Hello devops, Duoc!", Instant.now());
            when(greetingRepositoryPort.findAll()).thenReturn(List.of(greeting));

            List<Greeting> result = greetingService.findAllGreetings();

            assertThat(result).hasSize(1);
            assertThat(result.get(0).name()).isEqualTo("Duoc");
        }
    }

    @Nested
    @DisplayName("findGreetingById(Long id)")
    class FindGreetingById {

        @Test
        @DisplayName("returns greeting when found")
        void shouldReturnGreetingWhenFound() {
            Greeting greeting = new Greeting(1L, "Duoc", "Hello devops, Duoc!", Instant.now());
            when(greetingRepositoryPort.findById(1L)).thenReturn(Optional.of(greeting));

            Optional<Greeting> result = greetingService.findGreetingById(1L);

            assertThat(result).isPresent();
            assertThat(result.get().name()).isEqualTo("Duoc");
        }

        @Test
        @DisplayName("returns empty when not found")
        void shouldReturnEmptyWhenNotFound() {
            when(greetingRepositoryPort.findById(99L)).thenReturn(Optional.empty());

            Optional<Greeting> result = greetingService.findGreetingById(99L);

            assertThat(result).isEmpty();
        }
    }
}
