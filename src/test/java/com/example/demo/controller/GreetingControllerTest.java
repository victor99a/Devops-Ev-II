package com.example.demo.controller;

import com.example.demo.model.GreetingResponse;
import com.example.demo.service.GreetingService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(GreetingController.class)
class GreetingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GreetingService greetingService;

    @Nested
    @DisplayName("GET /api/v1/greeting")
    class GetGreeting {

        @Test
        @DisplayName("returns 200 with default name when no param provided")
        void shouldReturnGreetingWithDefaultName() throws Exception {
            var response = new GreetingResponse("Hello, World!", "World", Instant.now());

            when(greetingService.greet(anyString())).thenReturn(response);

            mockMvc.perform(get("/api/v1/greeting")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.message").value("Hello, World!"))
                    .andExpect(jsonPath("$.name").value("World"))
                    .andExpect(jsonPath("$.timestamp").exists());
        }

        @Test
        @DisplayName("returns 200 with custom name when param provided")
        void shouldReturnGreetingWithCustomName() throws Exception {
            var response = new GreetingResponse("Hello, Vito!", "Vito", Instant.now());

            when(greetingService.greet("Vito")).thenReturn(response);

            mockMvc.perform(get("/api/v1/greeting")
                            .param("name", "Vito")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.message").value("Hello, Vito!"))
                    .andExpect(jsonPath("$.name").value("Vito"))
                    .andExpect(jsonPath("$.timestamp").exists());
        }

        @Test
        @DisplayName("returns JSON content type")
        void shouldReturnJsonContentType() throws Exception {
            var response = new GreetingResponse("Hello, World!", "World", Instant.now());

            when(greetingService.greet(anyString())).thenReturn(response);

            mockMvc.perform(get("/api/v1/greeting")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.message").exists());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/health")
    class GetHealth {

        @Test
        @DisplayName("returns 200 with status UP")
        void shouldReturnStatusUp() throws Exception {
            mockMvc.perform(get("/api/v1/health")
                            .accept(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.status").value("UP"))
                    .andExpect(jsonPath("$.timestamp").exists());
        }
    }
}
