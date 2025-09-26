package com.acme.orders.service;

import com.acme.observability.annotation.OtelSpan;
import com.acme.observability.logging.ObservabilityHelper;
import com.acme.orders.domain.OrderEntity;
import com.acme.orders.repo.OrderRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Service
public class OrderService {

    private final OrderRepository repo;
    private final RestTemplate restTemplate;
    private final String inventoryBaseUrl;

    public OrderService(OrderRepository repo, RestTemplate restTemplate,
                        @Value("${inventory.base-url:http://inventory-service:8080}") String inventoryBaseUrl) {
        this.repo = repo;
        this.restTemplate = restTemplate;
        this.inventoryBaseUrl = inventoryBaseUrl;
    }

    @OtelSpan("OrderService.placeOrder")
    public OrderEntity place(String sku, int qty) {
        // Call inventory service to reserve stock
        String url = inventoryBaseUrl + "/inventory/reserve?sku=" + sku + "&qty=" + qty;
        ResponseEntity<String> resp = restTemplate.postForEntity(url, null, String.class);
        if (!resp.getStatusCode().is2xxSuccessful()) {
            throw new IllegalStateException("Inventory reserve failed: " + resp.getStatusCode());
        }
        OrderEntity e = OrderEntity.create(sku, qty);
        repo.save(e);
        ObservabilityHelper.logWithAttributes("order created", Map.of("order.id", e.getId(), "sku", sku, "qty", qty));
        return e;
    }

    @OtelSpan
    public List<OrderEntity> list() {
        return repo.findAll();
    }
}

