pkgname=ai-assistant
pkgver=0.1
pkgrel=1
pkgdesc="PRO Linux AI agent assistant"
arch=('any')
depends=('python' 'python-requests' 'ollama')
source=("agent.py" "tool.py" "ai")
sha256sums=('SKIP' 'SKIP' 'SKIP')

package() {
    install -Dm755 "$srcdir/ai" "$pkgdir/usr/bin/ai"
    install -Dm644 "$srcdir/agent.py" "$pkgdir/usr/lib/ai-assistant/agent.py"
    install -Dm644 "$srcdir/tool.py" "$pkgdir/usr/lib/ai-assistant/tool.py"
}