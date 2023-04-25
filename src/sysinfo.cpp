/*
 * Copyright (C) 2023 - Ed Beroset <beroset@ieee.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "sysinfo.h"

SysInfo::SysInfo(QObject *parent) :
    QObject(parent)
{
    sysinfo(&info);
    copyLoads();
}

void SysInfo::copyLoads() {
    static constexpr auto lf{1.0 / (1 << SI_LOAD_SHIFT)};
    m_loads = { info.loads[0]*lf, info.loads[1]*lf, info.loads[2]*lf };
}

void SysInfo::refresh() {
    auto oldinfo{info};
    sysinfo(&info);
    if (info.uptime != oldinfo.uptime) emit uptimeChanged();
    if ((info.loads[0] != oldinfo.loads[0]) ||
        (info.loads[1] != oldinfo.loads[1]) ||
        (info.loads[2] != oldinfo.loads[2])) 
    {
        copyLoads();
        emit loadsChanged();
    }
    if (info.totalram != oldinfo.totalram) emit totalramChanged();
    if (info.freeram != oldinfo.freeram) emit freeramChanged();
    if (info.sharedram != oldinfo.sharedram) emit sharedramChanged();
    if (info.bufferram != oldinfo.uptime) emit uptimeChanged();
    if (info.totalswap != oldinfo.totalswap) emit totalswapChanged();
    if (info.freeswap != oldinfo.freeswap) emit freeswapChanged();
    if (info.procs != oldinfo.procs) emit procsChanged();
    if (info.totalhigh != oldinfo.totalhigh) emit totalhighChanged();
    if (info.freehigh != oldinfo.freehigh) emit freehighChanged();

}
