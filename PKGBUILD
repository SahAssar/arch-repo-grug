pkgname=arch-repo-grug
pkgver=0.0.1
pkgver() {
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}
pkgrel=1
arch=('any')
pkgdesc="arch repo for grug"
url="https://git.grug.se/admin/arch-repo-grug"
license=('MIT')
makedepends=()
provides=()
conflicts=()
install="script.install"
package() {
  depends+=(rsync)
  depends+=(curl)
  depends+=(pacman-contrib)
  mkdir -p "$pkgdir/etc/systemd/system/"
  cp arch-repo-grug.timer "$pkgdir/etc/systemd/system/"
  cp arch-repo-grug.service "$pkgdir/etc/systemd/system/"
  cp -r arch-repo-grug "$pkgdir/etc/arch-repo-grug"
}
