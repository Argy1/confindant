<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    public function test_register_login_and_me_flow(): void
    {
        $register = $this->postJson('/api/v1/register', [
            'username' => 'tester',
            'email' => 'tester@example.com',
            'password' => 'secret123',
        ]);

        $register->assertStatus(201)->assertJsonPath('success', true);

        $login = $this->postJson('/api/v1/login', [
            'email' => 'tester@example.com',
            'password' => 'secret123',
        ]);

        $login->assertStatus(200)->assertJsonPath('success', true);

        $token = $login->json('data.access_token');
        $this->assertNotEmpty($token);
        $this->assertIsString($login->json('data.user.id'));

        $user = User::where('email', 'tester@example.com')->firstOrFail();
        Sanctum::actingAs($user);

        $this
            ->getJson('/api/v1/user')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['id', 'username', 'email'],
                'meta',
            ]);

        $this
            ->getJson('/api/v1/profile')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.profile.user_id', $login->json('data.user.id'));

        $this
            ->getJson('/api/v1/goals')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->getJson('/api/v1/habits')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->postJson('/api/v1/logout')
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }
}
