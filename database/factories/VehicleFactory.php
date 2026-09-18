<?php

namespace Database\Factories;

use App\Enums\VehicleType;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Vehicle>
 */
class VehicleFactory extends Factory
{
    /**
     * Manually curated pool of high-level vehicle records — no Faker.
     */
    protected static array $pool = [
        ['type' => VehicleType::Car, 'brand' => 'Mercedes-Benz', 'model' => 'S 580 4MATIC', 'year' => 2024, 'color' => 'Obsidian Black', 'owner_name' => 'James Anderson', 'owner_document' => '123-45-6789'],
        ['type' => VehicleType::Motorcycle, 'brand' => 'Ducati', 'model' => 'Panigale V4 S', 'year' => 2024, 'color' => 'Ducati Red', 'owner_name' => 'Emily Johnson', 'owner_document' => '234-56-7890'],
        ['type' => VehicleType::Truck, 'brand' => 'Kenworth', 'model' => 'T680', 'year' => 2023, 'color' => 'Midnight Blue', 'owner_name' => 'Midwest Logistics Inc.', 'owner_document' => '87-1234567'],
        ['type' => VehicleType::Car, 'brand' => 'Porsche', 'model' => '911 Carrera GTS', 'year' => 2024, 'color' => 'Arctic Silver', 'owner_name' => 'Michael Smith', 'owner_document' => '345-67-8901'],
        ['type' => VehicleType::Motorcycle, 'brand' => 'Harley-Davidson', 'model' => 'CVO Road Glide', 'year' => 2024, 'color' => 'Black', 'owner_name' => 'Sarah Davis', 'owner_document' => '456-78-9012'],
    ];

    public function definition(): array
    {
        $entry = static::$pool[static::$index ??= 0];
        static::$index = (static::$index + 1) % count(static::$pool);

        return [
            'plate' => strtoupper(substr(uniqid(), -3)).'-'.random_int(100, 999),
            'type' => $entry['type'],
            'brand' => $entry['brand'],
            'model' => $entry['model'],
            'year' => $entry['year'],
            'color' => $entry['color'],
            'owner_name' => $entry['owner_name'],
            'owner_document' => $entry['owner_document'],
            'created_by' => User::factory(),
        ];
    }
}