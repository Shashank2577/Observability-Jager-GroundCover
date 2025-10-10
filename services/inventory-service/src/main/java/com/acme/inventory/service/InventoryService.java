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
import java.util.Optional;

@Service
public class InventoryService {

    private final InventoryRepository repo;

    public InventoryService(InventoryRepository repo) { this.repo = repo; }

    @OtelSpan("InventoryService.list")
    public List<InventoryItem> list() { 
        ObservabilityHelper.logWithAttributes("listing all inventory", Map.of("operation", "list_all_inventory"));
        List<InventoryItem> items = repo.findAll();
        ObservabilityHelper.logWithAttributes("inventory retrieved", Map.of("count", items.size(), "operation", "inventory_retrieved"));
        return items;
    }

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
        ObservabilityHelper.logWithAttributes("stock added successfully", Map.of("sku", sku, "qty", qty, "total", item.getAvailable(), "operation", "stock_added"));
        return true;
    }

    @OtelSpan("InventoryService.findBySku")
    public Optional<InventoryItem> findBySku(String sku) {
        ObservabilityHelper.logWithAttributes("finding inventory by sku", Map.of("sku", sku, "operation", "find_inventory_by_sku"));
        Optional<InventoryItem> item = repo.findBySku(sku);
        if (item.isPresent()) {
            ObservabilityHelper.logWithAttributes("inventory found", Map.of("sku", sku, "available", item.get().getAvailable(), "operation", "inventory_found"));
        } else {
            ObservabilityHelper.logWithAttributes("inventory not found", Map.of("sku", sku, "operation", "inventory_not_found"));
        }
        return item;
    }

    @Transactional
    @OtelSpan("InventoryService.batchReserve")
    public Map<String, Object> batchReserve(List<Map<String, Object>> reservations) {
        ObservabilityHelper.logWithAttributes("processing batch reservations", Map.of("count", reservations.size(), "operation", "batch_reserve"));
        
        int successful = 0;
        int failed = 0;
        
        for (Map<String, Object> reservation : reservations) {
            String sku = (String) reservation.get("sku");
            Integer qty = (Integer) reservation.get("qty");
            if (reserve(sku, qty)) {
                successful++;
            } else {
                failed++;
            }
        }
        
        Map<String, Object> result = Map.of(
            "successful", successful,
            "failed", failed,
            "total", reservations.size()
        );
        
        ObservabilityHelper.logWithAttributes("batch reservations completed", Map.of("successful", successful, "failed", failed, "operation", "batch_reserve_completed"));
        return result;
    }

    @OtelSpan("InventoryService.getInventoryStats")
    public Map<String, Object> getInventoryStats() {
        ObservabilityHelper.logWithAttributes("calculating inventory statistics", Map.of("operation", "calculate_inventory_stats"));
        
        List<InventoryItem> allItems = repo.findAll();
        long totalItems = allItems.size();
        int totalStock = allItems.stream().mapToInt(InventoryItem::getAvailable).sum();
        int lowStockItems = (int) allItems.stream().filter(item -> item.getAvailable() < 10).count();
        
        Map<String, Object> stats = Map.of(
            "total_items", totalItems,
            "total_stock", totalStock,
            "low_stock_items", lowStockItems,
            "average_stock_per_item", totalItems > 0 ? (double) totalStock / totalItems : 0.0
        );
        
        ObservabilityHelper.logWithAttributes("inventory statistics calculated", Map.of("total_items", totalItems, "total_stock", totalStock, "operation", "inventory_stats_calculated"));
        return stats;
    }

    @OtelSpan("InventoryService.getLowStockItems")
    public List<InventoryItem> getLowStockItems(int threshold) {
        ObservabilityHelper.logWithAttributes("finding low stock items", Map.of("threshold", threshold, "operation", "find_low_stock"));
        
        List<InventoryItem> lowStockItems = repo.findAll().stream()
            .filter(item -> item.getAvailable() < threshold)
            .toList();
            
        ObservabilityHelper.logWithAttributes("low stock items found", Map.of("threshold", threshold, "count", lowStockItems.size(), "operation", "low_stock_found"));
        return lowStockItems;
    }

    @OtelSpan("InventoryService.getMetrics")
    public Map<String, Object> getMetrics() {
        ObservabilityHelper.logWithAttributes("getting service metrics", Map.of("operation", "get_service_metrics"));
        
        List<InventoryItem> allItems = repo.findAll();
        Map<String, Object> metrics = Map.of(
            "service_name", "inventory-service",
            "version", "1.11.0",
            "total_items", allItems.size(),
            "uptime_seconds", System.currentTimeMillis() / 1000,
            "memory_usage_mb", Runtime.getRuntime().totalMemory() / 1024 / 1024,
            "free_memory_mb", Runtime.getRuntime().freeMemory() / 1024 / 1024
        );
        
        ObservabilityHelper.logWithAttributes("service metrics retrieved", Map.of("total_items", allItems.size(), "operation", "service_metrics_retrieved"));
        return metrics;
    }
}

