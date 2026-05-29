package com.example.demo.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class GreetingServiceTest {

    private final GreetingService greetingService = new GreetingService();

    @Nested
    @DisplayName("greet(String name)")
    class GreetMethod {

        @Test
        @DisplayName("returns greeting with given name")
        void shouldGreetWithGivenName() {
            var response = greetingService.greet("Duoc");

            assertThat(response.message()).isEqualTo("Hello, Duoc!");
            assertThat(response.name()).isEqualTo("Duoc");
            assertThat(response.timestamp()).isNotNull();
        }

        @Test
        @DisplayName("falls back to World when name is null")
        void shouldFallbackToWorldWhenNameIsNull() {
            var response = greetingService.greet(null);

            assertThat(response.message()).isEqualTo("Hello, World!");
            assertThat(response.name()).isEqualTo("World");
            assertThat(response.timestamp()).isNotNull();
        }

        @Test
        @DisplayName("falls back to World when name is blank")
        void shouldFallbackToWorldWhenNameIsBlank() {
            var response = greetingService.greet("   ");

            assertThat(response.message()).isEqualTo("Hello, World!");
            assertThat(response.name()).isEqualTo("World");
            assertThat(response.timestamp()).isNotNull();
        }

        @Test
        @DisplayName("falls back to World when name is empty string")
        void shouldFallbackToWorldWhenNameIsEmpty() {
            var response = greetingService.greet("");

            assertThat(response.message()).isEqualTo("Hello, World!");
            assertThat(response.name()).isEqualTo("World");
            assertThat(response.timestamp()).isNotNull();
        }

        @Test
        @DisplayName("response contains current timestamp")
        void shouldContainCurrentTimestamp() {
            var before = java.time.Instant.now();
            var response = greetingService.greet("Test");
            var after = java.time.Instant.now();

            assertThat(response.timestamp()).isBetween(before, after);
        }
    }
}
