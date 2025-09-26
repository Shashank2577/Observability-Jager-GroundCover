package com.acme.observability.async;

import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Supplier;

@Component
public class ContextPropagationHelper {

    private final ExecutorService delegate = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());

    public <T> CompletableFuture<T> supplyAsync(Supplier<T> supplier) {
        Context captured = Context.current();
        return CompletableFuture.supplyAsync(() -> {
            try (Scope scope = captured.makeCurrent()) {
                return supplier.get();
            }
        }, delegate);
    }

    public CompletableFuture<Void> runAsync(Runnable runnable) {
        Context captured = Context.current();
        return CompletableFuture.runAsync(() -> {
            try (Scope scope = captured.makeCurrent()) {
                runnable.run();
            }
        }, delegate);
    }
}
