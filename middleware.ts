import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

type CookieToSet = { name: string; value: string; options?: CookieOptions };

function securityHeaders(response: NextResponse) {
  response.headers.set("X-Content-Type-Options", "nosniff");
  response.headers.set("X-Frame-Options", "DENY");
  response.headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
  response.headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=(), usb=()");
  response.headers.set("Cross-Origin-Opener-Policy", "same-origin");
  response.headers.set("X-DNS-Prefetch-Control", "off");
  response.headers.set("Strict-Transport-Security", "max-age=63072000; includeSubDomains; preload");
  response.headers.set(
    "Content-Security-Policy",
    "default-src 'self'; base-uri 'self'; frame-ancestors 'none'; object-src 'none'; form-action 'self'; img-src 'self' data: blob: https:; font-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; connect-src 'self' https://*.supabase.co wss://*.supabase.co; upgrade-insecure-requests"
  );
  return response;
}

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll(); },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
        },
      },
    }
  );

  const { data: { user } } = await supabase.auth.getUser();
  const pathname = request.nextUrl.pathname;
  const isPrivate = pathname.startsWith("/dashboard") || pathname.startsWith("/admin") || pathname.startsWith("/cambiar-contrasena");

  if (!user && isPrivate) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return securityHeaders(NextResponse.redirect(url));
  }

  if (user) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("active,force_password_change")
      .eq("id", user.id)
      .maybeSingle();

    if (!profile || profile.active === false) {
      if (pathname !== "/login") {
        const url = request.nextUrl.clone();
        url.pathname = "/login";
        url.searchParams.set("error", "access");
        return securityHeaders(NextResponse.redirect(url));
      }
    } else if (profile.force_password_change && pathname !== "/cambiar-contrasena") {
      const url = request.nextUrl.clone();
      url.pathname = "/cambiar-contrasena";
      return securityHeaders(NextResponse.redirect(url));
    } else if (!profile.force_password_change && (pathname === "/login" || pathname === "/cambiar-contrasena")) {
      const url = request.nextUrl.clone();
      url.pathname = "/dashboard";
      return securityHeaders(NextResponse.redirect(url));
    }
  }

  return securityHeaders(response);
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
