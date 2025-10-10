package com.acme.orders.repo;

import com.acme.orders.domain.OrderEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface OrderRepository extends JpaRepository<OrderEntity, String> {
    List<OrderEntity> findBySku(String sku);
}

