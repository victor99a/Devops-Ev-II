package com.example.demo.infrastructure.inbound.controller;

import com.example.demo.domain.model.Greeting;
import com.example.demo.domain.port.inbound.CreateGreetingUseCase;
import com.example.demo.domain.port.inbound.LifecycleUseCase;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(GreetingController.class)
class GreetingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CreateGreetingUseCase createGreetingUseCase;

    @MockBean
    private LifecycleUseCase lifecycleUseCase;

    @Nested
    @DisplayName("GET /api/v1/greetings")
    class GetAllGreetings {

        @Test
        @DisplayName("returns 200 with empty list")
        void shouldReturnEmptyList() throws Exception {
            when(lifecycleUseCase.findAllGreetings()).thenReturn(List.of());

            mockMvc.perform(get("/api/v1/greetings")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$").isEmpty());
        }

        @Test
        @DisplayName("returns 200 with list of greetings")
        void shouldReturnListOfGreetings() throws Exception {
            Greeting greeting = new Greeting(1L, "Duoc", "Hello, Duoc!", Instant.now());
            when(lifecycleUseCase.findAllGreetings()).thenReturn(List.of(greeting));

            mockMvc.perform(get("/api/v1/greetings")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$[0].id").value(1))
                    .andExpect(jsonPath("$[0].name").value("Duoc"))
                    .andExpect(jsonPath("$[0].message").value("Hello, Duoc!"))
                    .andExpect(jsonPath("$[0].timestamp").exists());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/greetings")
    class CreateGreeting {

        @Test
        @DisplayName("returns 201 with created greeting using default name")
        void shouldCreateGreetingWithDefaultName() throws Exception {
            Greeting greeting = new Greeting(1L, "World", "Hello, World!", Instant.now());
            when(createGreetingUseCase.createGreeting(anyString())).thenReturn(greeting);

            mockMvc.perform(post("/api/v1/greetings")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.id").value(1))
                    .andExpect(jsonPath("$.name").value("World"))
                    .andExpect(jsonPath("$.message").value("Hello, World!"))
                    .andExpect(jsonPath("$.timestamp").exists());
        }

        @Test
        @DisplayName("returns 201 with created greeting using custom name")
        void shouldCreateGreetingWithCustomName() throws Exception {
            Greeting greeting = new Greeting(2L, "Vito", "Hello, Vito!", Instant.now());
            when(createGreetingUseCase.createGreeting("Vito")).thenReturn(greeting);

            mockMvc.perform(post("/api/v1/greetings")
                            .param("name", "Vito")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.id").value(2))
                    .andExpect(jsonPath("$.name").value("Vito"))
                    .andExpect(jsonPath("$.message").value("Hello, Vito!"))
                    .andExpect(jsonPath("$.timestamp").exists());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/greetings/{id}")
    class GetGreetingById {

        @Test
        @DisplayName("returns 200 when greeting found")
        void shouldReturnGreetingWhenFound() throws Exception {
            Greeting greeting = new Greeting(1L, "Duoc", "Hello, Duoc!", Instant.now());
            when(lifecycleUseCase.findGreetingById(1L)).thenReturn(Optional.of(greeting));

            mockMvc.perform(get("/api/v1/greetings/1")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.id").value(1))
                    .andExpect(jsonPath("$.name").value("Duoc"))
                    .andExpect(jsonPath("$.message").value("Hello, Duoc!"))
                    .andExpect(jsonPath("$.timestamp").exists());
        }

        @Test
        @DisplayName("returns 404 when greeting not found")
        void shouldReturn404WhenNotFound() throws Exception {
            when(lifecycleUseCase.findGreetingById(99L)).thenReturn(Optional.empty());

            mockMvc.perform(get("/api/v1/greetings/99")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isNotFound());
        }
    }
}
