<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class VehicleApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_operator_can_list_vehicles(): void
    {
        $operator = User::factory()->create(['role' => UserRole::Operador]);
        Vehicle::factory()->count(3)->create(['created_by' => $operator->id]);

        $this->actingAs($operator, 'sanctum')
            ->getJson('/api/vehicles')
            ->assertOk()
            ->assertJsonCount(3, 'data');
    }

    public function test_operator_cannot_delete_vehicle(): void
    {
        $operator = User::factory()->create(['role' => UserRole::Operador]);
        $vehicle = Vehicle::factory()->create(['created_by' => $operator->id]);

        $this->actingAs($operator, 'sanctum')
            ->deleteJson("/api/vehicles/{$vehicle->id}")
            ->assertForbidden();
    }

    public function test_admin_can_delete_vehicle(): void
    {
        $admin = User::factory()->admin()->create();
        $vehicle = Vehicle::factory()->create(['created_by' => $admin->id]);

        $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/vehicles/{$vehicle->id}")
            ->assertNoContent();
    }
}
