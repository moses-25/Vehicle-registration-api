<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->string('plate', 10)->unique();
            $table->enum('type', ['car', 'suv', 'truck', 'motorcycle']);
            $table->string('brand', 50);
            $table->string('model', 50);
            $table->integer('year');
            $table->string('color', 20);
            $table->string('owner_name', 100);
            $table->string('owner_document', 30);
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};
