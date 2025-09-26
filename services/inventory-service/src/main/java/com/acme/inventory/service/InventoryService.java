package com.acme.inventory.service;

import com.acme.inventory.domain.InventoryItem;
import com.acme.inventory.repo.InventoryRepository;
import com.acme.observability.annotation.OtelSpan;
import com.acme.observability.logging.ObservabilityHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;

@Service
public class InventoryService {

    private final InventoryRepository repo;

    public InventoryService(InventoryRepository repo) { this.repo = repo; }

    @OtelSpan
    public List<InventoryItem> list() { return repo.findAll(); }

    @Transactional
    @OtelSpan("InventoryService.reserve")
    public boolean reserve(String sku, int qty) {
        InventoryItem item = repo.findBySku(sku).orElseGet(() -> {
            InventoryItem created = InventoryItem.create(sku, 100); // default stock
            return repo.save(created);
        });
        if (item.getAvailable() < qty) {
            ObservabilityHelper.logWithAttributes("not enough stock", Map.of("sku", sku, "available", item.getAvailable(), "requested", qty));
            return false;
        }
        item.setAvailable(item.getAvailable() - qty);
        item.setUpdatedAt(Instant.now());
        repo.save(item);
        ObservabilityHelper.logWithAttributes("reserved stock", Map.of("sku", sku, "qty", qty, "remaining", item.getAvailable()));
        return true;
    }

    @Transactional
    @OtelSpan("InventoryService.addStock")
    public boolean addStock(String sku, int qty) {
        InventoryItem item = repo.findBySku(sku).orElseGet(() -> {
            InventoryItem created = InventoryItem.create(sku, 0);
            return repo.save(created);
        });
        item.setAvailable(item.getAvailable() + qty);
        item.setUpdatedAt(Instant.now());
        repo.save(item);
        ObservabilityHelper.logWithAttributes("added stock", Map.of("sku", sku, "qty", qty, "total", item.getAvailable()));
        return true;
    }
}

