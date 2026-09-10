<?php

namespace App\Enums;

enum VehicleType: string
{
    case Car = 'car';
    case SUV = 'suv';
    case Truck = 'truck';
    case Motorcycle = 'motorcycle';
}