<?php

namespace Tests\Feature\Api\Concerns;

use App\Models\User;

trait ApiAuthHelpers
{
    protected function createUserWithToken(
        string $username = 'test-user',
        string $email = 'test@example.com',
        string $password = 'secret123'
    ): array {
        $user = User::create([
            'username' => $username,
            'email' => $email,
            'password' => bcrypt($password),
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        return [$user, $token];
    }
}
