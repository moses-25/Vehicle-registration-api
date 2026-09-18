<?php

namespace Database\Factories;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected static ?string $password;

    /**
     * Manually curated pool of American names/emails — no Faker.
     */
    protected static array $pool = [
        ['name' => 'James Anderson', 'email' => 'james.anderson@example.com'],
        ['name' => 'Emily Johnson', 'email' => 'emily.johnson@example.com'],
        ['name' => 'Michael Williams', 'email' => 'michael.williams@example.com'],
        ['name' => 'Olivia Brown', 'email' => 'olivia.brown@example.com'],
        ['name' => 'Daniel Miller', 'email' => 'daniel.miller@example.com'],
    ];

    public function definition(): array
    {
        $entry = static::$pool[static::$count ??= 0];
        static::$count = (static::$count + 1) % count(static::$pool);

        // Ensure uniqueness across multiple calls within the same test run.
        $suffix = uniqid();

        return [
            'name' => $entry['name'],
            'email' => str_replace('@', "+{$suffix}@", $entry['email']),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'role' => UserRole::Operador,
            'remember_token' => substr(uniqid('', true), 0, 10),
        ];
    }

    public function admin(): static
    {
        return $this->state(fn (array $attributes) => ['role' => UserRole::Administrador]);
    }

    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => ['email_verified_at' => null]);
    }
}
