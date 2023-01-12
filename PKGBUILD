pkgname=arch-repo-grug
pkgver=0.0.1
pkgver() {
  # Use number of revisions and hash as version
  cd "$pkgname"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}
pkgrel=1
arch=('any')
pkgdesc="arch repo for grug"
url="https://git.grug.se/admin/arch-repo-grug"
license=('MIT')
depends=('rsync' 'curl' 'pacman-contrib')
makedepends=()
provides=()
conflicts=()
install="script.install"
package() {
  mkdir -p "$pkgdir/etc/systemd/system/"
  cp arch-repo-grug.timer "$pkgdir/etc/systemd/system/"
  cp arch-repo-grug.service "$pkgdir/etc/systemd/system/"
  cp -r arch-repo-grug "$pkgdir/etc/arch-repo-grug"
}
