$path = 'C:\xampp\htdocs\bellavellaa\routes\api.php'
$content = Get-Content -Raw -Path $path
$old = @"
                // Cart
                Route::get('cart', [CartController::class , 'index']);
                Route::post('cart', [CartController::class , 'store']);
                Route::put('cart/{cart}', [CartController::class , 'update']);
                Route::delete('cart/{cart}', [CartController::class , 'destroy']);
                Route::post('cart/clear', [CartController::class , 'clear']);
                Route::post('cart/sync', [CartController::class , 'sync']);
                Route::post('cart/checkout', [CartController::class , 'checkout']);
                Route::post('cart/checkout/verify', [CartController::class , 'verifyCheckout']);
"@
$new = @"
                // Cart
                Route::get('cart', [CartController::class , 'index']);
                Route::post('cart', [CartController::class , 'store']);
                Route::put('cart/{cart}', [CartController::class , 'update']);
                Route::delete('cart/{cart}', [CartController::class , 'destroy']);
                Route::post('cart/clear', [CartController::class , 'clear']);
                Route::post('cart/sync', [CartController::class , 'sync']);
                Route::post('cart/checkout/preview', [CartController::class , 'previewCheckout']);
                Route::post('cart/checkout', [CartController::class , 'checkout']);
                Route::post('cart/checkout/verify', [CartController::class , 'verifyCheckout']);
"@

if ($content -notlike "*cart/checkout/preview*") {
  if (-not $content.Contains($old)) {
    throw "Old cart route block not found."
  }
  $content = $content.Replace($old, $new)
  Set-Content -Path $path -Value $content
}

Get-Content -Path $path | Select-Object -Skip 118 -First 20
