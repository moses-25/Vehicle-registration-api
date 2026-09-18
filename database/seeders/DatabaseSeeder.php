<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Enums\VehicleType;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $admin = User::create([
            'name' => 'James Anderson',
            'email' => 'james.anderson@example.com',
            'password' => Hash::make('password'),
            'role' => UserRole::Administrator,
        ]);

        $operator = User::create([
            'name' => 'Emily Johnson',
            'email' => 'emily.johnson@example.com',
            'password' => Hash::make('password'),
            'role' => UserRole::Operator,
        ]);

        // Manually entered vehicle records (registered by the admin)
        $adminVehicles = [
            [
                'plate' => 'JAD-580',
                'type' => VehicleType::Car,
                'brand' => 'Mercedes-Benz',
                'model' => 'S 580 4MATIC',
                'year' => 2024,
                'color' => 'Obsidian Black',
                'owner_name' => 'James Anderson',
                'owner_document' => '123-45-6789',
            ],
            [
                'plate' => 'EJH-421',
                'type' => VehicleType::Motorcycle,
                'brand' => 'Ducati',
                'model' => 'Panigale V4 S',
                'year' => 2024,
                'color' => 'Ducati Red',
                'owner_name' => 'Emily Johnson',
                'owner_document' => '234-56-7890',
            ],
            [
                'plate' => 'MLI-783',
                'type' => VehicleType::Truck,
                'brand' => 'Kenworth',
                'model' => 'T680',
                'year' => 2023,
                'color' => 'Midnight Blue',
                'owner_name' => 'Midwest Logistics Inc.',
                'owner_document' => '87-1234567',
            ],
            [
                'plate' => 'MSP-902',
                'type' => VehicleType::Car,
                'brand' => 'Porsche',
                'model' => '911 Carrera GTS',
                'year' => 2024,
                'color' => 'Arctic Silver',
                'owner_name' => 'Michael Smith',
                'owner_document' => '345-67-8901',
            ],
            [
                'plate' => 'SDC-347',
                'type' => VehicleType::Motorcycle,
                'brand' => 'Harley-Davidson',
                'model' => 'CVO Road Glide',
                'year' => 2024,
                'color' => 'Black',
                'owner_name' => 'Sarah Davis',
                'owner_document' => '456-78-9012',
            ],
        ];

        $operatorVehicles = [
            [
                'plate' => 'JAM-615',
                'type' => VehicleType::Car,
                'brand' => 'BMW',
                'model' => 'M5 Competition',
                'year' => 2023,
                'color' => 'Alpine White',
                'owner_name' => 'James Anderson',
                'owner_document' => '123-45-6789',
            ],
            [
                'plate' => 'EJS-824',
                'type' => VehicleType::Motorcycle,
                'brand' => 'BMW Motorrad',
                'model' => 'M 1000 RR',
                'year' => 2023,
                'color' => 'Black',
                'owner_name' => 'Emily Johnson',
                'owner_document' => '234-56-7890',
            ],
            [
                'plate' => 'MLT-492',
                'type' => VehicleType::Truck,
                'brand' => 'Freightliner',
                'model' => 'Cascadia',
                'year' => 2024,
                'color' => 'Glacier White',
                'owner_name' => 'Midwest Logistics Inc.',
                'owner_document' => '87-1234567',
            ],
            [
                'plate' => 'MSR-736',
                'type' => VehicleType::SUV,
                'brand' => 'Cadillac',
                'model' => 'Escalade-V',
                'year' => 2024,
                'color' => 'Black Raven',
                'owner_name' => 'Michael Smith',
                'owner_document' => '345-67-8901',
            ],
            [
                'plate' => 'SDH-158',
                'type' => VehicleType::Motorcycle,
                'brand' => 'Indian Motorcycle',
                'model' => 'Challenger Elite',
                'year' => 2023,
                'color' => 'Ruby Metallic',
                'owner_name' => 'Sarah Davis',
                'owner_document' => '456-78-9012',
            ],
        ];

        foreach ($adminVehicles as $data) {
            Vehicle::create([...$data, 'created_by' => $admin->id]);
        }

        foreach ($operatorVehicles as $data) {
            Vehicle::create([...$data, 'created_by' => $operator->id]);
        }
    }
}
